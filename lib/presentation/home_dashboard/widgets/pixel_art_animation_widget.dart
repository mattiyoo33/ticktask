import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../services/ai_service.dart';

/// Pixel art animation widget that displays animations based on active tasks
/// Similar to Pokemon game style animations
class PixelArtAnimationWidget extends StatefulWidget {
  final List<Map<String, dynamic>> activeTasks;
  final AIService? aiService;

  const PixelArtAnimationWidget({
    super.key,
    required this.activeTasks,
    this.aiService,
  });

  @override
  State<PixelArtAnimationWidget> createState() => _PixelArtAnimationWidgetState();
}

class _PixelArtAnimationWidgetState extends State<PixelArtAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;
  String _currentAnimation = 'idle';
  String _currentCharacter = 'default';
  Map<String, dynamic>? _currentTask;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _updateAnimation();
    _animationController.repeat();
  }

  @override
  void didUpdateWidget(PixelArtAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeTasks != widget.activeTasks) {
      _updateAnimation();
    }
  }

  Future<void> _updateAnimation() async {
    if (widget.activeTasks.isEmpty) {
      setState(() {
        _currentAnimation = 'idle';
        _currentCharacter = 'default';
        _currentTask = null;
      });
      return;
    }

    // Get the first active task
    final task = widget.activeTasks.first;
    _currentTask = task;

    // Get animation suggestion from AI or use fallback
    Map<String, dynamic> animationData;
    if (widget.aiService != null) {
      try {
        animationData = await widget.aiService!.getAnimationForTask(
          title: task['title'] ?? '',
          description: task['description'],
        );
      } catch (e) {
        // Fallback to keyword-based
        animationData = _getAnimationFromKeywords(
          task['title'] ?? '',
          task['description'] ?? '',
        );
      }
    } else {
      animationData = _getAnimationFromKeywords(
        task['title'] ?? '',
        task['description'] ?? '',
      );
    }

    setState(() {
      _currentAnimation = animationData['animationType'] ?? 'idle';
      _currentCharacter = animationData['character'] ?? 'default';
    });

    // Trigger bounce animation
    _animationController.reset();
    _animationController.forward();
  }

  Map<String, dynamic> _getAnimationFromKeywords(String title, String description) {
    final text = ('$title $description').toLowerCase();
    
    String animationType = 'idle';
    String character = 'default';

    if (text.contains('work') || text.contains('meeting') || text.contains('code')) {
      animationType = 'working';
      character = 'worker';
    } else if (text.contains('exercise') || text.contains('workout') || text.contains('gym')) {
      animationType = 'running';
      character = 'athlete';
    } else if (text.contains('study') || text.contains('learn') || text.contains('read')) {
      animationType = 'reading';
      character = 'student';
    } else if (text.contains('draw') || text.contains('paint') || text.contains('design')) {
      animationType = 'creating';
      character = 'artist';
    } else if (text.contains('cook') || text.contains('recipe') || text.contains('food')) {
      animationType = 'cooking';
      character = 'chef';
    } else if (text.contains('shop') || text.contains('buy') || text.contains('grocery')) {
      animationType = 'walking';
      character = 'shopper';
    }

    return {
      'animationType': animationType,
      'character': character,
    };
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.activeTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Active Task Animation',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          // Pixel art animation area
          Center(
            child: AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.8 + (_bounceAnimation.value * 0.2),
                  child: _buildPixelArtCharacter(),
                );
              },
            ),
          ),
          SizedBox(height: 2.h),
          // Task info
          if (_currentTask != null)
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentTask!['title'] ?? 'Task',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _getAnimationDescription(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPixelArtCharacter() {
    // Pixel art style character using Flutter widgets
    // This is a placeholder - you can replace with actual pixel art sprites
    return Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(
        color: _getCharacterColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black,
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Body
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: _getCharacterColor(),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black, width: 1),
            ),
          ),
          // Eyes
          Positioned(
            top: 4.w,
            left: 3.w,
            child: Container(
              width: 1.5.w,
              height: 1.5.w,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 4.w,
            right: 3.w,
            child: Container(
              width: 1.5.w,
              height: 1.5.w,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Animation indicator
          Positioned(
            bottom: 2.w,
            child: _buildAnimationIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationIndicator() {
    IconData icon;
    switch (_currentAnimation) {
      case 'working':
        icon = Icons.computer;
        break;
      case 'running':
        icon = Icons.directions_run;
        break;
      case 'reading':
        icon = Icons.menu_book;
        break;
      case 'creating':
        icon = Icons.brush;
        break;
      case 'cooking':
        icon = Icons.restaurant;
        break;
      case 'walking':
        icon = Icons.directions_walk;
        break;
      default:
        icon = Icons.accessibility_new;
    }

    return Icon(
      icon,
      size: 4.w,
      color: Colors.black,
    );
  }

  Color _getCharacterColor() {
    switch (_currentCharacter) {
      case 'worker':
        return Colors.blue.shade300;
      case 'athlete':
        return Colors.red.shade300;
      case 'student':
        return Colors.purple.shade300;
      case 'artist':
        return Colors.pink.shade300;
      case 'chef':
        return Colors.orange.shade300;
      case 'shopper':
        return Colors.green.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  String _getAnimationDescription() {
    switch (_currentAnimation) {
      case 'working':
        return '💼 Working hard on this task!';
      case 'running':
        return '🏃 Stay active and keep moving!';
      case 'reading':
        return '📚 Learning and growing!';
      case 'creating':
        return '🎨 Creating something amazing!';
      case 'cooking':
        return '👨‍🍳 Time to cook up something great!';
      case 'walking':
        return '🛒 Let\'s get this done!';
      default:
        return '✨ Ready to tackle this task!';
    }
  }
}

