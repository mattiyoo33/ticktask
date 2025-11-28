import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RecurringTaskWidget extends StatelessWidget {
  final bool isRecurring;
  final String frequency;
  final List<String> selectedDays;
  final Function(bool) onRecurringChanged;
  final Function(String) onFrequencyChanged;
  final Function(String) onDayToggled;

  const RecurringTaskWidget({
    super.key,
    required this.isRecurring,
    required this.frequency,
    required this.selectedDays,
    required this.onRecurringChanged,
    required this.onFrequencyChanged,
    required this.onDayToggled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recurring Task',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Switch(
              value: isRecurring,
              onChanged: onRecurringChanged,
            ),
          ],
        ),
        if (isRecurring) ...[
          SizedBox(height: 2.h),
          _buildFrequencySelector(context),
          if (frequency == 'Custom') ...[
            SizedBox(height: 2.h),
            _buildDaySelector(context),
          ],
        ],
      ],
    );
  }

  Widget _buildFrequencySelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final frequencies = ['Daily', 'Weekly', 'Custom'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequency',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: frequencies.map((freq) {
            final isSelected = frequency == freq;
            return Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(right: freq != frequencies.last ? 2.w : 0),
                child: GestureDetector(
                  onTap: () => onFrequencyChanged(freq),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      freq,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDaySelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Days',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: days.map((day) {
            final isSelected = selectedDays.contains(day);
            return GestureDetector(
              onTap: () => onDayToggled(day),
              child: Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    day,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
