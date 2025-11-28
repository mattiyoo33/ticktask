import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DifficultySelectionWidget extends StatelessWidget {
  final String selectedDifficulty;
  final Function(String) onDifficultyChanged;

  const DifficultySelectionWidget({
    super.key,
    required this.selectedDifficulty,
    required this.onDifficultyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Difficulty Level',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildDifficultyCard(
                context,
                'Easy',
                '10 XP',
                AppTheme.lightTheme.colorScheme.secondary,
                CustomIconWidget(
                  iconName: 'star_outline',
                  color: AppTheme.lightTheme.colorScheme.secondary,
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildDifficultyCard(
                context,
                'Medium',
                '20 XP',
                AppTheme.lightTheme.colorScheme.primary,
                CustomIconWidget(
                  iconName: 'star_half',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildDifficultyCard(
                context,
                'Hard',
                '30 XP',
                AppTheme.lightTheme.colorScheme.tertiary,
                CustomIconWidget(
                  iconName: 'star',
                  color: AppTheme.lightTheme.colorScheme.tertiary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyCard(
    BuildContext context,
    String difficulty,
    String xpValue,
    Color accentColor,
    Widget icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = selectedDifficulty == difficulty;

    return GestureDetector(
      onTap: () => onDifficultyChanged(difficulty),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? accentColor
                : colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            icon,
            SizedBox(height: 1.h),
            Text(
              difficulty,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? accentColor : colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              xpValue,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? accentColor : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
