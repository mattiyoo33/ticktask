import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../home_dashboard/widgets/tasker_mascot_widget.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  final bool isFirstTime;
  
  const TutorialScreen({
    super.key,
    this.isFirstTime = false,
  });

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  int _currentStep = 0;

  final List<TutorialStep> _steps = [
    TutorialStep(
      title: 'Welcome to TickTask! 👋',
      description: "I'm Tasker, your friendly guide! Let me show you around the app.",
      icon: Icons.home,
      screenName: 'Home',
    ),
    TutorialStep(
      title: 'Create Tasks 📝',
      description: 'Tap the + button to create tasks. Set due dates, add descriptions, and earn XP when you complete them!',
      icon: Icons.task_alt,
      screenName: 'Tasks',
    ),
    TutorialStep(
      title: 'Organize with Plans 📋',
      description: 'Create Plans to group multiple tasks together. Perfect for daily routines or special events!',
      icon: Icons.event_note,
      screenName: 'Plans',
    ),
    TutorialStep(
      title: 'Discover & Collaborate 🌟',
      description: 'Explore public tasks and plans created by others. Join challenges and collaborate with friends!',
      icon: Icons.explore,
      screenName: 'Discover',
    ),
    TutorialStep(
      title: 'More Features ⚙️',
      description: 'Access your profile, friends, achievements, and settings from the More section.',
      icon: Icons.more_horiz,
      screenName: 'More',
    ),
  ];

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      HapticFeedback.lightImpact();
    } else {
      _completeTutorial();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _skipTutorial() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Tutorial?'),
        content: const Text('You can always access the tutorial again from Settings. Are you sure you want to skip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _completeTutorial();
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeTutorial() async {
    try {
      final tutorialService = ref.read(tutorialServiceProvider);
      await tutorialService.markTutorialCompleted();
      
      // CRITICAL: Invalidate the provider to ensure fresh data is fetched
      ref.invalidate(tutorialCompletedProvider);
      
      // Wait for the provider to refresh to prevent race condition
      await ref.read(tutorialCompletedProvider.future);
      
      if (mounted) {
        HapticFeedback.mediumImpact();
        if (widget.isFirstTime) {
          Navigator.pushReplacementNamed(context, AppRoutes.homeDashboard);
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Error completing tutorial: $e');
      if (mounted) {
        if (widget.isFirstTime) {
          Navigator.pushReplacementNamed(context, AppRoutes.homeDashboard);
        } else {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentStepData = _steps[_currentStep];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / _steps.length,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      minHeight: 4,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${_currentStep + 1}/${_steps.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Skip/Close button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: widget.isFirstTime
                    ? TextButton(
                        onPressed: _skipTutorial,
                        child: Text(
                          'Skip',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 4.h),
                    
                    // Tasker Mascot
                    TaskerMascotWidget(
                      state: MascotState.greeting,
                      message: currentStepData.description,
                    ),
                    
                    SizedBox(height: 6.h),
                    
                    // Icon
                    Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        currentStepData.icon,
                        size: 12.w,
                        color: colorScheme.primary,
                      ),
                    ),
                    
                    SizedBox(height: 4.h),
                    
                    // Title
                    Text(
                      currentStepData.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 2.h),
                    
                    // Screen name badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        currentStepData.screenName,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 4.h),
                    
                    // Description
                    Text(
                      currentStepData.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                        ),
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentStep > 0) SizedBox(width: 4.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                      ),
                      child: Text(
                        _currentStep == _steps.length - 1 ? 'Get Started!' : 'Next',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final String screenName;

  TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.screenName,
  });
}

