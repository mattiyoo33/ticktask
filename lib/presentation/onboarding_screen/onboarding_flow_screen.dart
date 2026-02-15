import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/onboarding_service.dart';
import '../../routes/app_routes.dart';
import 'name_input_screen.dart';
import 'affirmation_settings_screen.dart';
import 'widgets/question_screen.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  final OnboardingService _onboardingService = OnboardingService();
  int _currentStep = 0;
  String? _userName;
  String? _gender;
  String? _ageRange;
  String? _religion;
  String? _employmentStatus;
  String? _affirmationFamiliarity;
  String? _selfReflectionFrequency;
  List<String> _affirmationHabits = [];
  String? _referralSource;

  void _handleNameSubmitted(String name) {
    setState(() {
      _userName = name.isEmpty ? null : name;
    });
    _onboardingService.saveUserName(_userName ?? '');
    _nextStep();
  }

  void _handleGenderSelected(String gender) {
    setState(() {
      _gender = gender;
    });
    _onboardingService.saveGender(gender);
    _nextStep();
  }

  void _handleAgeRangeSelected(String ageRange) {
    setState(() {
      _ageRange = ageRange;
    });
    _onboardingService.saveAgeRange(ageRange);
    _nextStep();
  }

  void _handleReligionSelected(String religion) {
    setState(() {
      _religion = religion;
    });
    _onboardingService.saveReligion(religion);
    _nextStep();
  }

  void _handleEmploymentStatusSelected(String status) {
    setState(() {
      _employmentStatus = status;
    });
    _onboardingService.saveEmploymentStatus(status);
    _nextStep();
  }

  void _handleAffirmationFamiliaritySelected(String familiarity) {
    setState(() {
      _affirmationFamiliarity = familiarity;
    });
    _onboardingService.saveAffirmationFamiliarity(familiarity);
    _nextStep();
  }

  void _handleSelfReflectionFrequencySelected(String frequency) {
    setState(() {
      _selfReflectionFrequency = frequency;
    });
    _onboardingService.saveSelfReflectionFrequency(frequency);
    _nextStep();
  }

  void _handleAffirmationHabitsSelected(List<String> habits) {
    setState(() {
      _affirmationHabits = habits;
    });
    _onboardingService.saveAffirmationHabits(habits);
  }

  void _handleReferralSourceSelected(String source) {
    setState(() {
      _referralSource = source;
    });
    _onboardingService.saveReferralSource(source);
    _nextStep();
  }

  void _handleAffirmationSettingsSaved({
    required int count,
    required String startTime,
    required String endTime,
  }) {
    _onboardingService.saveAffirmationSettings(
      count: count,
      startTime: startTime,
      endTime: endTime,
    );
    _completeOnboarding();
  }

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
  }

  void _skipStep() {
    _nextStep();
  }

  Future<void> _completeOnboarding() async {
    // TEMPORARY: Commented out for testing - always show onboarding
    // await _onboardingService.markOnboardingCompleted();
    
    // TEMPORARY: Just navigate without marking as completed
    if (mounted) {
      // Navigate to login or home based on auth state
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      if (isAuthenticated) {
        Navigator.pushReplacementNamed(context, AppRoutes.homeDashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  Widget _buildCurrentScreen() {
    switch (_currentStep) {
      case 0:
        return NameInputScreen(
          initialName: _userName,
          onNameSubmitted: _handleNameSubmitted,
        );
      
      case 1:
        return QuestionScreen(
          question: 'Which option represents you best${_userName != null ? ', $_userName' : ''}?',
          subtitle: 'Some affirmations will use your gender or pronouns',
          options: ['Female', 'Male', 'Others', 'Prefer not to say'],
          selectedValue: _gender,
          onOptionSelected: _handleGenderSelected,
          onSkip: _skipStep,
          userName: _userName,
        );
      
      case 2:
        return QuestionScreen(
          question: 'How old are you?',
          subtitle: 'Your age is used to personalize your content.',
          options: [
            '13 to 17',
            '18 to 24',
            '25 to 34',
            '35 to 44',
            '45 to 54',
            '55+',
          ],
          selectedValue: _ageRange,
          onOptionSelected: _handleAgeRangeSelected,
          onSkip: _skipStep,
        );
      
      case 3:
        return QuestionScreen(
          question: 'Are you religious?',
          subtitle: 'This information will be used to tailor your affirmations to your beliefs',
          options: [
            'Yes',
            'No',
            'Spiritual but not religious',
          ],
          selectedValue: _religion,
          onOptionSelected: _handleReligionSelected,
          onSkip: _skipStep,
        );
      
      case 4:
        return QuestionScreen(
          question: 'What\'s your employment status?',
          subtitle: 'Choose the option that describes it the best',
          options: [
            'Studying',
            'Looking for a job',
            'Working',
            'Retired',
            'Stay at home parent',
            'Other',
          ],
          selectedValue: _employmentStatus,
          onOptionSelected: _handleEmploymentStatusSelected,
          onSkip: _skipStep,
        );
      
      case 5:
        return QuestionScreen(
          question: 'How familiar are you with affirmations${_userName != null ? ', $_userName' : ''}?',
          subtitle: 'Your experience will be adjusted according to your answer',
          options: [
            'This is new for me',
            'I\'ve used them occasionally',
            'I use them regularly',
          ],
          selectedValue: _affirmationFamiliarity,
          onOptionSelected: _handleAffirmationFamiliaritySelected,
          onSkip: _skipStep,
          userName: _userName,
        );
      
      case 6:
        return QuestionScreen(
          question: 'How often do you pause to check in with yourself?',
          subtitle: 'This information will be used to personalize your affirmations',
          options: [
            'Multiple times a day',
            'Once or twice a day',
            'Rarely, I forget to',
            'I\'m not sure how to',
          ],
          selectedValue: _selfReflectionFrequency,
          onOptionSelected: _handleSelfReflectionFrequencySelected,
          onSkip: _skipStep,
        );
      
      case 7:
        return QuestionScreen(
          question: 'What would help make affirmations a daily habit?',
          subtitle: 'You can select more than one option',
          options: [
            'Getting regular reminders',
            'Tracking my progress',
            'A home/lock screen widget',
            'A guided practice',
            'I don\'t know yet',
          ],
          selectedValues: _affirmationHabits,
          allowMultipleSelection: true,
          onOptionsSelected: _handleAffirmationHabitsSelected,
          onContinue: () {
            _onboardingService.saveAffirmationHabits(_affirmationHabits);
            _nextStep();
          },
          onSkip: _skipStep,
        );
      
      case 8:
        return QuestionScreen(
          question: 'How did you hear about I am?',
          subtitle: 'Select an option to continue',
          options: [
            'App Store',
            'Instagram',
            'Facebook',
            'Friend/family',
            'Web search',
            'TikTok',
            'Other',
          ],
          selectedValue: _referralSource,
          onOptionSelected: _handleReferralSourceSelected,
          onSkip: _skipStep,
        );
      
      case 9:
        return AffirmationSettingsScreen(
          onSettingsSaved: _handleAffirmationSettingsSaved,
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildCurrentScreen();
  }
}
