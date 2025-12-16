/// Plan Creation Screen
/// 
/// Allows users to create a new plan with a title, optional description, date, and time range.
/// After creating a plan, users can add tasks to it from the plan detail screen.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../task_creation_screen/widgets/category_selection_widget.dart';

class PlanCreationScreen extends ConsumerStatefulWidget {
  const PlanCreationScreen({super.key});

  @override
  ConsumerState<PlanCreationScreen> createState() => _PlanCreationScreenState();
}

class _PlanCreationScreenState extends ConsumerState<PlanCreationScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;
  bool _isPublicPlan = false;
  String? _selectedCategoryId; // Category ID for public plans

  @override
  void initState() {
    super.initState();
    // No need to check arguments anymore - user can toggle public/private on the screen
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              headerBackgroundColor: Theme.of(context).colorScheme.primary,
              headerForegroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 22, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _handleCreatePlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Validate category selection for public plans
      if (_isPublicPlan && _selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a category for your public plan'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final planService = ref.read(planServiceProvider);
      final plan = await planService.createPlan(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        planDate: _selectedDate,
        startTime: _startTime != null ? _formatTimeOfDay(_startTime!) : null,
        endTime: _endTime != null ? _formatTimeOfDay(_endTime!) : null,
        isPublic: _isPublicPlan,
        categoryId: _isPublicPlan ? _selectedCategoryId : null,
      );

      ref.invalidate(allPlansProvider);

      if (mounted) {
        Navigator.pop(context);
        Navigator.pushNamed(
          context,
          '/plan-detail-screen',
          arguments: plan['id'] as String,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan created successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating plan: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Create Plan',
        variant: CustomAppBarVariant.standard,
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Public/Private Toggle
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPublicPlan = false;
                        });
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        decoration: BoxDecoration(
                          color: !_isPublicPlan
                              ? colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'lock',
                              color: !_isPublicPlan
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                              size: 5.w,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Private',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: !_isPublicPlan
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: !_isPublicPlan
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPublicPlan = true;
                        });
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        decoration: BoxDecoration(
                          color: _isPublicPlan
                              ? colorScheme.secondary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'public',
                              color: _isPublicPlan
                                  ? colorScheme.onSecondary
                                  : colorScheme.onSurfaceVariant,
                              size: 5.w,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Public',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: _isPublicPlan
                                    ? colorScheme.onSecondary
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: _isPublicPlan
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
        child: ListView(
          padding: EdgeInsets.all(4.w),
          children: [
            SizedBox(height: 2.h),
            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Plan Title *',
                hintText: 'e.g., Monday Plan, Weekend Study Plan',
                prefixIcon: CustomIconWidget(
                  iconName: 'title',
                  color: colorScheme.primary,
                  size: 24,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a plan title';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: 3.h),
            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add a short description about this plan',
                prefixIcon: CustomIconWidget(
                  iconName: 'description',
                  color: colorScheme.secondary,
                  size: 24,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: 3.h),
            
            // Category Selection (only for public plans)
            if (_isPublicPlan) ...[
              CategorySelectionWidget(
                selectedCategoryId: _selectedCategoryId,
                onCategorySelected: (categoryId) {
                  setState(() {
                    _selectedCategoryId = categoryId;
                  });
                },
              ),
              SizedBox(height: 3.h),
            ],
            
            // Date Selection
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'calendar',
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plan Date',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            _selectedDate != null
                                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                : 'Select date (optional)',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: _selectedDate != null
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedDate != null)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedDate = null;
                          });
                        },
                        icon: Icon(
                          Icons.clear,
                          color: colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 3.h),
            // Time Range
            Text(
              'Time Range (Optional)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectStartTime,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'schedule',
                            color: colorScheme.secondary,
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Time',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  _startTime != null
                                      ? _formatTimeOfDay(_startTime!)
                                      : 'Not set',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: _startTime != null
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: InkWell(
                    onTap: _selectEndTime,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'schedule',
                            color: colorScheme.secondary,
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End Time',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  _endTime != null
                                      ? _formatTimeOfDay(_endTime!)
                                      : 'Not set',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: _endTime != null
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleCreatePlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 2.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 2.h,
                        width: 2.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Text(
                        _isPublicPlan ? 'Create Public Plan' : 'Create Private Plan',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimary,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 2.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

