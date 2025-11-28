import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

enum TaskFilter { all, active, completed, easy, medium, hard }

enum TaskSort { dueDate, priority, difficulty, creationDate }

class SearchFilterBarWidget extends StatefulWidget {
  final String searchQuery;
  final TaskFilter currentFilter;
  final TaskSort currentSort;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<TaskFilter>? onFilterChanged;
  final ValueChanged<TaskSort>? onSortChanged;
  final VoidCallback? onClearSearch;

  const SearchFilterBarWidget({
    super.key,
    this.searchQuery = '',
    this.currentFilter = TaskFilter.all,
    this.currentSort = TaskSort.dueDate,
    this.onSearchChanged,
    this.onFilterChanged,
    this.onSortChanged,
    this.onClearSearch,
  });

  @override
  State<SearchFilterBarWidget> createState() => _SearchFilterBarWidgetState();
}

class _SearchFilterBarWidgetState extends State<SearchFilterBarWidget> {
  late TextEditingController _searchController;
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isSearchFocused
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: widget.onSearchChanged,
                    onTap: () {
                      setState(() => _isSearchFocused = true);
                      HapticFeedback.lightImpact();
                    },
                    onTapOutside: (_) =>
                        setState(() => _isSearchFocused = false),
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: CustomIconWidget(
                          iconName: 'search',
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      suffixIcon: widget.searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                widget.onClearSearch?.call();
                                HapticFeedback.lightImpact();
                              },
                              icon: CustomIconWidget(
                                iconName: 'clear',
                                color: colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 3.h,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              // Filter Button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showFilterBottomSheet(context);
                },
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: widget.currentFilter != TaskFilter.all
                        ? colorScheme.primary
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.currentFilter != TaskFilter.all
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: CustomIconWidget(
                    iconName: 'tune',
                    color: widget.currentFilter != TaskFilter.all
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),

          // Filter Chips
          if (widget.currentFilter != TaskFilter.all ||
              widget.currentSort != TaskSort.dueDate) ...[
            SizedBox(height: 2.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (widget.currentFilter != TaskFilter.all)
                    _buildFilterChip(
                      context,
                      _getFilterDisplayName(widget.currentFilter),
                      () {
                        widget.onFilterChanged?.call(TaskFilter.all);
                        HapticFeedback.lightImpact();
                      },
                    ),
                  if (widget.currentSort != TaskSort.dueDate) ...[
                    if (widget.currentFilter != TaskFilter.all)
                      SizedBox(width: 2.w),
                    _buildFilterChip(
                      context,
                      'Sort: ${_getSortDisplayName(widget.currentSort)}',
                      () {
                        widget.onSortChanged?.call(TaskSort.dueDate);
                        HapticFeedback.lightImpact();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      BuildContext context, String label, VoidCallback onRemove) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 1.w),
          GestureDetector(
            onTap: onRemove,
            child: CustomIconWidget(
              iconName: 'close',
              color: colorScheme.primary,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 3.h),

            // Filter Section
            Text(
              'Filter by Status',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: TaskFilter.values.map((filter) {
                final isSelected = widget.currentFilter == filter;
                return GestureDetector(
                  onTap: () {
                    widget.onFilterChanged?.call(filter);
                    Navigator.pop(context);
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _getFilterDisplayName(filter),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 4.h),

            // Sort Section
            Text(
              'Sort by',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: TaskSort.values.map((sort) {
                final isSelected = widget.currentSort == sort;
                return GestureDetector(
                  onTap: () {
                    widget.onSortChanged?.call(sort);
                    Navigator.pop(context);
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _getSortDisplayName(sort),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  String _getFilterDisplayName(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return 'All Tasks';
      case TaskFilter.active:
        return 'Active';
      case TaskFilter.completed:
        return 'Completed';
      case TaskFilter.easy:
        return 'Easy';
      case TaskFilter.medium:
        return 'Medium';
      case TaskFilter.hard:
        return 'Hard';
    }
  }

  String _getSortDisplayName(TaskSort sort) {
    switch (sort) {
      case TaskSort.dueDate:
        return 'Due Date';
      case TaskSort.priority:
        return 'Priority';
      case TaskSort.difficulty:
        return 'Difficulty';
      case TaskSort.creationDate:
        return 'Creation Date';
    }
  }
}
