import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';

class AITaskGeneratorWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onTaskGenerated;

  const AITaskGeneratorWidget({
    super.key,
    required this.onTaskGenerated,
  });

  @override
  State<AITaskGeneratorWidget> createState() => _AITaskGeneratorWidgetState();
}

class _AITaskGeneratorWidgetState extends State<AITaskGeneratorWidget> {
  final TextEditingController _promptController = TextEditingController();
  bool _isGenerating = false;
  final AIService _aiService = AIService();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateTask() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task description'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    HapticFeedback.mediumImpact();

    try {
      final generatedTask = await _aiService.generateTaskFromPrompt(prompt);
      
      // Call the callback with generated task
      widget.onTaskGenerated(generatedTask);
      
      // Clear the prompt
      _promptController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CustomIconWidget(
                  iconName: 'auto_awesome',
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                const Expanded(
                  child: Text('Task generated successfully!'),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to generate task';
        Color? backgroundColor = Theme.of(context).colorScheme.error;
        Duration duration = const Duration(seconds: 3);
        
        if (e is AIServiceException) {
          if (e.type == AIServiceErrorType.quotaExceeded) {
            errorMessage = 'OpenAI quota exceeded. You can still create tasks manually below.';
            backgroundColor = Colors.orange;
            duration = const Duration(seconds: 5);
          } else if (e.type == AIServiceErrorType.rateLimitExceeded) {
            errorMessage = 'Rate limit exceeded. Please try again in a moment.';
            backgroundColor = Colors.orange;
          } else {
            errorMessage = e.message;
          }
        } else {
          errorMessage = 'Failed to generate task: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CustomIconWidget(
                  iconName: e is AIServiceException && e.type == AIServiceErrorType.quotaExceeded
                      ? 'info'
                      : 'error',
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: backgroundColor,
            behavior: SnackBarBehavior.floating,
            duration: duration,
            action: e is AIServiceException && e.type == AIServiceErrorType.quotaExceeded
                ? SnackBarAction(
                    label: 'OK',
                    textColor: Colors.white,
                    onPressed: () {},
                  )
                : null,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomIconWidget(
                  iconName: 'auto_awesome',
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Task Generator',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Describe your task and let AI create it for you',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          TextField(
            controller: _promptController,
            maxLines: 3,
            enabled: !_isGenerating,
            decoration: InputDecoration(
              hintText: 'e.g., "Workout for 30 minutes every morning" or "Complete the project report by Friday"',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'edit',
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              suffixIcon: _promptController.text.isNotEmpty && !_isGenerating
                  ? IconButton(
                      onPressed: () {
                        _promptController.clear();
                        setState(() {});
                      },
                      icon: CustomIconWidget(
                        iconName: 'clear',
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 4.w,
                vertical: 3.h,
              ),
            ),
            onChanged: (value) => setState(() {}),
            onSubmitted: (_) => _generateTask(),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating || _promptController.text.trim().isEmpty
                  ? null
                  : _generateTask,
              icon: _isGenerating
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : CustomIconWidget(
                      iconName: 'auto_awesome',
                      color: Colors.white,
                      size: 20,
                    ),
              label: Text(_isGenerating ? 'Generating...' : 'Generate Task'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

