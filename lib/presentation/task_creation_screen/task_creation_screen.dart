import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/advanced_options_widget.dart';
import './widgets/difficulty_selection_widget.dart';
import './widgets/quick_templates_widget.dart';
import './widgets/recurring_task_widget.dart';
import './widgets/ai_task_generator_widget.dart';
import './widgets/select_collaborators_modal_widget.dart';
import './widgets/category_selection_widget.dart';
import '../discover_screen/widgets/task_type_choice_modal.dart';
import '../../providers/service_providers.dart';

class TaskCreationScreen extends ConsumerStatefulWidget {
  const TaskCreationScreen({super.key});

  @override
  ConsumerState<TaskCreationScreen> createState() => _TaskCreationScreenState();
}

class _TaskCreationScreenState extends ConsumerState<TaskCreationScreen>
    with TickerProviderStateMixin {
  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Task properties
  String _selectedDifficulty = 'Easy';
  DateTime? _selectedDueDate;
  bool _isRecurring = false;
  String _recurringFrequency = 'Daily';
  final List<String> _selectedDays = [];

  // Advanced options
  bool _advancedOptionsExpanded = false;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _collaborationEnabled = false;
  String _selectedCategory = 'Personal';
  List<String> _selectedCollaboratorIds = []; // Selected friend IDs for collaboration
  
  // Public task options
  bool _isPublicTask = false;
  String? _selectedCategoryId; // Category ID for public tasks
  String? _planCategoryId; // Category inherited from plan (public plan)
  String? _planCategoryName; // Display name if we fetch it

  // Plan options
  String? _planId; // Plan ID if task is being added to a plan

  // UI state
  bool _isLoading = false;
  bool _showTemplates = true;
  bool _hasCheckedArguments = false;

  // Animation controllers
  late AnimationController _saveButtonController;
  late Animation<double> _saveButtonAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _titleController.addListener(_validateForm);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check arguments only once after dependencies are available
    if (!_hasCheckedArguments) {
    _checkArguments();
    }
  }

  Future<void> _checkArguments() async {
    if (!mounted || _hasCheckedArguments) return;
    
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
      // Check for planId if task is being added to a plan
        final planId = args['planId'] as String?;
      if (planId != null) {
        // Fetch plan to check if it's public
        try {
          final planService = ref.read(planServiceProvider);
          final plan = await planService.getPlanById(planId);
          if (plan != null) {
            final isPlanPublic = plan['is_public'] as bool? ?? false;
            final planCategoryId = plan['category_id'] as String?;
            setState(() {
              _planId = planId;
              // Automatically set task public status based on plan
              _isPublicTask = isPlanPublic;
              _planCategoryId = planCategoryId;
              _selectedCategoryId = planCategoryId; // Inherit category; hide selector
            });
          } else {
            setState(() {
              _planId = planId;
            });
          }
        } catch (e) {
          debugPrint('Error fetching plan: $e');
          setState(() {
            _planId = planId;
          });
        }
      }
    }
    // Don't show modal automatically - users come through the selection modal
    _hasCheckedArguments = true;
  }

  void _showTaskTypeChoice() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.w)),
      ),
      builder: (modalContext) => TaskTypeChoiceModal(
        onTaskSelected: () {
          Navigator.pop(modalContext); // Close modal, stay on task creation screen
          // User can toggle public/private
        },
        onPlanSelected: () {
          Navigator.pop(modalContext); // Close modal first
          Navigator.pop(context); // Close task creation screen
          Navigator.pushNamed(context, '/plan-creation-screen');
        },
      ),
    );
  }

  void _initializeAnimations() {
    _saveButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _saveButtonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _saveButtonController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _saveButtonController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {});
  }

  bool get _isFormValid {
    return _titleController.text.trim().isNotEmpty;
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              headerBackgroundColor: Theme.of(context).colorScheme.primary,
              headerForegroundColor: Theme.of(context).colorScheme.onPrimary,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context).colorScheme.onPrimary;
                }
                return Theme.of(context).colorScheme.onSurface;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context).colorScheme.primary;
                }
                return Colors.transparent;
              }),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  void _onTemplateSelected(Map<String, dynamic> template) {
    setState(() {
      _titleController.text = template['title'];
      _descriptionController.text = template['description'];
      _selectedDifficulty = template['difficulty'];
      _selectedCategory = template['category'];
      _showTemplates = false;
    });

    // Provide haptic feedback
    HapticFeedback.lightImpact();
  }

  void _onAITaskGenerated(Map<String, dynamic> generatedTask) {
    setState(() {
      _titleController.text = generatedTask['title'] ?? '';
      _descriptionController.text = generatedTask['description'] ?? '';
      _selectedDifficulty = generatedTask['difficulty'] ?? 'Medium';
      _selectedCategory = generatedTask['category'] ?? 'Personal';
      _showTemplates = false;
      
      // Set due date if suggested
      if (generatedTask['suggestedDueDate'] != null) {
        try {
          _selectedDueDate = DateTime.parse(generatedTask['suggestedDueDate']);
        } catch (e) {
          // Ignore date parsing errors
        }
      }
    });

    // Provide haptic feedback
    HapticFeedback.mediumImpact();
    
    // Scroll to top to show the filled form
    // Note: You might want to add a ScrollController for this
  }

  void _onDayToggled(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  void _handleSelectCollaborators() async {
    final selectedIds = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectCollaboratorsModalWidget(
        selectedFriendIds: _selectedCollaboratorIds,
      ),
    );

    if (selectedIds != null && mounted) {
      setState(() {
        _selectedCollaboratorIds = selectedIds;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_isFormValid) return;

    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
    });

    _saveButtonController.forward();

    try {
      // Calculate XP based on difficulty
      int xpReward = _selectedDifficulty == 'Easy'
          ? 10
          : _selectedDifficulty == 'Medium'
              ? 20
              : 30;

      // Get TaskService and create task in database
      final taskService = ref.read(taskServiceProvider);
      
      // Parse due time if reminder is enabled
      String? dueTime;
      if (_reminderEnabled) {
        dueTime = '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}';
      }
      
      // Calculate next occurrence for recurring tasks
      DateTime? nextOccurrence;
      if (_isRecurring && _selectedDueDate != null) {
        switch (_recurringFrequency) {
          case 'Daily':
            nextOccurrence = _selectedDueDate!.add(const Duration(days: 1));
            break;
          case 'Weekly':
            nextOccurrence = _selectedDueDate!.add(const Duration(days: 7));
            break;
          case 'Monthly':
            nextOccurrence = DateTime(
              _selectedDueDate!.year,
              _selectedDueDate!.month + 1,
              _selectedDueDate!.day,
            );
            break;
          default:
            nextOccurrence = _selectedDueDate;
        }
      }

      Map<String, dynamic>? createdTask;
      bool createdPublic = false;
      String? createdPlanId;

      // Create task in database
      if (_planId != null) {
        // Always create via taskService when adding to a plan (even if plan is public)
        int? taskOrder;
        try {
          final planService = ref.read(planServiceProvider);
          final plan = await planService.getPlanById(_planId!);
          final tasks = plan?['tasks'] as List<dynamic>? ?? [];
          taskOrder = tasks.length;
        } catch (e) {
          debugPrint('Error fetching plan for task order: $e');
        }

        createdTask = await taskService.createTask(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          difficulty: _selectedDifficulty,
          dueDate: _selectedDueDate,
          dueTime: dueTime,
          xpReward: xpReward,
          isRecurring: _isRecurring,
          recurrenceFrequency: _isRecurring ? _recurringFrequency : null,
          recurrenceInterval: 1,
          nextOccurrence: nextOccurrence,
          isCollaborative: _collaborationEnabled,
          participantIds: _collaborationEnabled ? _selectedCollaboratorIds : [],
          planId: _planId,
          taskOrder: taskOrder,
          isPublic: null, // inherit from plan (plan_service will set)
        );
        createdPublic = createdTask['is_public'] == true;
        createdPlanId = createdTask['plan_id'] as String?;
      } else if (_isPublicTask) {
        // Create standalone public task
        if (_selectedCategoryId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select a category for your public task')),
          );
          setState(() => _isLoading = false);
          return;
        }

        final publicTaskService = ref.read(publicTaskServiceProvider);
        createdTask = await publicTaskService.createPublicTask(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          categoryId: _selectedCategoryId!,
          dueDate: _selectedDueDate,
          difficulty: _selectedDifficulty.toLowerCase(),
        );
        createdPublic = true;
      } else {
        // Private/normal standalone task
        createdTask = await taskService.createTask(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          difficulty: _selectedDifficulty,
          dueDate: _selectedDueDate,
          dueTime: dueTime,
          xpReward: xpReward,
          isRecurring: _isRecurring,
          recurrenceFrequency: _isRecurring ? _recurringFrequency : null,
          recurrenceInterval: 1,
          nextOccurrence: nextOccurrence,
          isCollaborative: _collaborationEnabled,
          participantIds: _collaborationEnabled ? _selectedCollaboratorIds : [],
          planId: null,
          taskOrder: null,
          isPublic: false,
        );
        createdPublic = false;
        createdPlanId = null;
      }

      // Refresh public feeds for discover
      if (createdPublic) {
        ref.invalidate(publicTasksProvider(const PublicTaskFilters()));
      }

      // Refresh plan if task was added to a plan
      if (createdPlanId != null) {
        ref.invalidate(planByIdProvider(createdPlanId));
        ref.invalidate(allPlansProvider);
        // If the plan is public, refresh public plans feed so task count updates
        if (createdPublic) {
          ref.invalidate(publicPlansProvider(const PublicPlanFilters()));
        }
        // Refresh plan stats (task counts/progress) immediately
        ref.invalidate(planStatsProvider(createdPlanId));
      }

      // Refresh personal task lists
      ref.invalidate(allTasksProvider);
      ref.invalidate(todaysTasksProvider);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CustomIconWidget(
                  iconName: 'check_circle',
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Task created successfully!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Navigate back to home
        // If task was added to a plan, return true to refresh plan detail screen
        Navigator.pop(context, _planId != null ? true : null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CustomIconWidget(
                  iconName: 'error',
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Failed to create task: ${e.toString()}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _saveButtonController.reverse();
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_titleController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty) {
      final bool? shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Discard Changes?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          content: Text(
            'You have unsaved changes. Are you sure you want to discard them?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Discard',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(
            _isPublicTask ? 'Create Public Task' : 'Create Task',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          leading: IconButton(
            icon: CustomIconWidget(
              iconName: 'close',
              color: colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            AnimatedBuilder(
              animation: _saveButtonAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _saveButtonAnimation.value,
                  child: TextButton(
                    onPressed: _isFormValid && !_isLoading ? _saveTask : null,
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary,
                              ),
                            ),
                          )
                        : Text(
                            'Save',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _isFormValid
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
          backgroundColor: colorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 2,
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
                child: _planId != null
                    ? Container(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        decoration: BoxDecoration(
                          color: _isPublicTask
                              ? colorScheme.secondary
                              : colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: _isPublicTask ? 'public' : 'lock',
                              color: _isPublicTask
                                  ? colorScheme.onSecondary
                                  : colorScheme.onPrimary,
                              size: 5.w,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              _isPublicTask ? 'Public (Plan is Public)' : 'Private (Plan is Private)',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: _isPublicTask
                                    ? colorScheme.onSecondary
                                    : colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isPublicTask = false;
                                });
                                HapticFeedback.lightImpact();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: !_isPublicTask
                                      ? colorScheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'lock',
                                      color: !_isPublicTask
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurfaceVariant,
                                      size: 5.w,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'Private',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: !_isPublicTask
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurfaceVariant,
                                        fontWeight: !_isPublicTask
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
                                  _isPublicTask = true;
                                });
                                HapticFeedback.lightImpact();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: _isPublicTask
                                      ? colorScheme.secondary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'public',
                                      color: _isPublicTask
                                          ? colorScheme.onSecondary
                                          : colorScheme.onSurfaceVariant,
                                      size: 5.w,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'Public',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: _isPublicTask
                                            ? colorScheme.onSecondary
                                            : colorScheme.onSurfaceVariant,
                                        fontWeight: _isPublicTask
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI Task Generator
                AITaskGeneratorWidget(
                  onTaskGenerated: _onAITaskGenerated,
                ),
                SizedBox(height: 4.h),
                Divider(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
                SizedBox(height: 4.h),
                
                // Quick Templates
                if (_showTemplates) ...[
                  QuickTemplatesWidget(
                    onTemplateSelected: _onTemplateSelected,
                  ),
                  SizedBox(height: 4.h),
                  Divider(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  SizedBox(height: 4.h),
                ],

                // Task Title
                Text(
                  'Task Title',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 1.h),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Enter task title...',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: CustomIconWidget(
                        iconName: 'task_alt',
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                  style: theme.textTheme.bodyLarge,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 3.h),

                // Task Description
                Text(
                  'Description',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 1.h),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Add task description (optional)...',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: CustomIconWidget(
                        iconName: 'description',
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                  style: theme.textTheme.bodyLarge,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                SizedBox(height: 3.h),

                // Due Date
                Text(
                  'Due Date',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 1.h),
                GestureDetector(
                  onTap: _selectDueDate,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'calendar_today',
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            _selectedDueDate != null
                                ? '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}'
                                : 'Select due date (optional)',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: _selectedDueDate != null
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        CustomIconWidget(
                          iconName: 'keyboard_arrow_right',
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 4.h),

                // Difficulty Selection
                DifficultySelectionWidget(
                  selectedDifficulty: _selectedDifficulty,
                  onDifficultyChanged: (difficulty) {
                    setState(() {
                      _selectedDifficulty = difficulty;
                    });
                    HapticFeedback.lightImpact();
                  },
                ),
                SizedBox(height: 4.h),

                // Recurring Task
                RecurringTaskWidget(
                  isRecurring: _isRecurring,
                  frequency: _recurringFrequency,
                  selectedDays: _selectedDays,
                  onRecurringChanged: (value) {
                    setState(() {
                      _isRecurring = value;
                      if (!value) {
                        _selectedDays.clear();
                      }
                    });
                  },
                  onFrequencyChanged: (frequency) {
                    setState(() {
                      _recurringFrequency = frequency;
                      if (frequency != 'Custom') {
                        _selectedDays.clear();
                      }
                    });
                  },
                  onDayToggled: _onDayToggled,
                ),
                SizedBox(height: 4.h),

                // Category Selection (for standalone public tasks only)
                if (_isPublicTask && _planId == null) ...[
                  CategorySelectionWidget(
                    selectedCategoryId: _selectedCategoryId,
                    onCategorySelected: (categoryId) {
                      setState(() {
                        _selectedCategoryId = categoryId;
                      });
                    },
                  ),
                  SizedBox(height: 4.h),
                ],

                // Advanced Options (only for private tasks)
                if (!_isPublicTask) ...[
                  AdvancedOptionsWidget(
                  isExpanded: _advancedOptionsExpanded,
                  reminderEnabled: _reminderEnabled,
                  reminderTime: _reminderTime,
                  collaborationEnabled: _collaborationEnabled,
                  selectedCategory: _selectedCategory,
                  onToggleExpanded: () {
                    setState(() {
                      _advancedOptionsExpanded = !_advancedOptionsExpanded;
                    });
                  },
                  onReminderToggled: (value) {
                    setState(() {
                      _reminderEnabled = value;
                    });
                  },
                  onReminderTimeChanged: (time) {
                    setState(() {
                      _reminderTime = time;
                    });
                  },
                  onCollaborationToggled: (value) {
                    setState(() {
                      _collaborationEnabled = value;
                      if (!value) {
                        _selectedCollaboratorIds.clear();
                      }
                    });
                  },
                  onCategoryChanged: (category) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  selectedCollaboratorIds: _selectedCollaboratorIds,
                  onSelectCollaborators: _collaborationEnabled ? _handleSelectCollaborators : null,
                  ),
                  SizedBox(height: 4.h),
                ],

                // Create Task Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isFormValid && !_isLoading ? _saveTask : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: _isFormValid ? 2 : 0,
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Text(
                                'Creating Task...',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomIconWidget(
                                iconName: 'add_task',
                                color: _isFormValid
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                'Create Task',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: _isFormValid
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 4.h),
              ],
            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
