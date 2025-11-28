import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class BatchActionsToolbarWidget extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onSelectAll;
  final VoidCallback? onDeselectAll;
  final VoidCallback? onCompleteSelected;
  final VoidCallback? onDeleteSelected;
  final VoidCallback? onShareSelected;
  final VoidCallback? onCancel;

  const BatchActionsToolbarWidget({
    super.key,
    required this.selectedCount,
    this.onSelectAll,
    this.onDeselectAll,
    this.onCompleteSelected,
    this.onDeleteSelected,
    this.onShareSelected,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.15),
            offset: const Offset(0, -2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Cancel button
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onCancel?.call();
              },
              icon: CustomIconWidget(
                iconName: 'close',
                color: colorScheme.onPrimary,
                size: 24,
              ),
            ),

            SizedBox(width: 2.w),

            // Selected count
            Expanded(
              child: Text(
                '$selectedCount selected',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Select All/Deselect All
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                selectedCount > 0 ? onDeselectAll?.call() : onSelectAll?.call();
              },
              child: Text(
                selectedCount > 0 ? 'Deselect All' : 'Select All',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            SizedBox(width: 2.w),

            // Action buttons
            Row(
              children: [
                // Complete selected
                IconButton(
                  onPressed: selectedCount > 0
                      ? () {
                          HapticFeedback.mediumImpact();
                          onCompleteSelected?.call();
                        }
                      : null,
                  icon: CustomIconWidget(
                    iconName: 'check_circle',
                    color: selectedCount > 0
                        ? colorScheme.onPrimary
                        : colorScheme.onPrimary.withValues(alpha: 0.5),
                    size: 24,
                  ),
                ),

                // Share selected
                IconButton(
                  onPressed: selectedCount > 0
                      ? () {
                          HapticFeedback.lightImpact();
                          onShareSelected?.call();
                        }
                      : null,
                  icon: CustomIconWidget(
                    iconName: 'share',
                    color: selectedCount > 0
                        ? colorScheme.onPrimary
                        : colorScheme.onPrimary.withValues(alpha: 0.5),
                    size: 24,
                  ),
                ),

                // Delete selected
                IconButton(
                  onPressed: selectedCount > 0
                      ? () {
                          HapticFeedback.heavyImpact();
                          _showDeleteConfirmation(context);
                        }
                      : null,
                  icon: CustomIconWidget(
                    iconName: 'delete',
                    color: selectedCount > 0
                        ? colorScheme.onPrimary
                        : colorScheme.onPrimary.withValues(alpha: 0.5),
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Tasks',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete $selectedCount selected task${selectedCount > 1 ? 's' : ''}? This action cannot be undone.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDeleteSelected?.call();
              HapticFeedback.heavyImpact();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: Text(
              'Delete',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onError,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
