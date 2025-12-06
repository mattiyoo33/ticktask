import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Category Filter Widget
/// 
/// Displays a horizontal scrollable list of categories for filtering public tasks
class CategoryFilterWidget extends ConsumerWidget {
  final String? selectedCategoryId;
  final Function(String?) onCategorySelected;

  const CategoryFilterWidget({
    super.key,
    this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      height: 12.h,
      padding: EdgeInsets.symmetric(vertical: 2.h),
      color: colorScheme.surface,
      child: categoriesAsync.when(
        data: (categories) {
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            children: [
              // "All" option
              _buildCategoryChip(
                context,
                label: 'All',
                icon: 'apps',
                isSelected: selectedCategoryId == null,
                onTap: () => onCategorySelected(null),
              ),
              SizedBox(width: 2.w),
              // Category chips
              ...categories.map((category) {
                final categoryId = category['id'] as String;
                final categoryName = category['name'] as String;
                final categoryIcon = category['icon'] as String? ?? 'category';
                
                return Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: _buildCategoryChip(
                    context,
                    label: categoryName,
                    icon: categoryIcon,
                    isSelected: selectedCategoryId == categoryId,
                    onTap: () => onCategorySelected(
                      selectedCategoryId == categoryId ? null : categoryId,
                    ),
                  ),
                );
              }),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (_, __) => SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context, {
    required String label,
    required String icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

