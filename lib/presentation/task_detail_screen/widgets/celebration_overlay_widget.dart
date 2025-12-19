import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class CelebrationOverlayWidget extends StatefulWidget {
  final bool isVisible;
  final int xpGained;
  final VoidCallback? onAnimationComplete;

  const CelebrationOverlayWidget({
    super.key,
    required this.isVisible,
    required this.xpGained,
    this.onAnimationComplete,
  });

  @override
  State<CelebrationOverlayWidget> createState() =>
      _CelebrationOverlayWidgetState();
}

class _CelebrationOverlayWidgetState extends State<CelebrationOverlayWidget>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _xpController;
  late Animation<double> _confettiAnimation;
  late Animation<double> _xpScaleAnimation;
  late Animation<double> _xpOpacityAnimation;

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      duration: Duration(milliseconds: 1400),
      vsync: this,
    );

    _xpController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _confettiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    ));

    _xpScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _xpController,
      curve: Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _xpOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _xpController,
      curve: Interval(0.7, 1.0, curve: Curves.easeIn),
    ));

    _xpController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Wait a bit before dismissing to let users see the full celebration
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            widget.onAnimationComplete?.call();
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(CelebrationOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      // Reset animations before starting
      _confettiController.reset();
      _xpController.reset();
      _startCelebration();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      // Reset animations when hiding
      _confettiController.reset();
      _xpController.reset();
    }
  }

  void _startCelebration() {
    _confettiController.forward();
    _xpController.forward();

    // Fallback to ensure overlay dismisses even if status listener misses
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted && widget.isVisible) {
        widget.onAnimationComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: Container(
          color: Colors.black.withValues(alpha: 0.18),
          child: Stack(
            children: [
              // Confetti particles
              AnimatedBuilder(
                animation: _confettiAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ConfettiPainter(_confettiAnimation.value),
                    size: Size.infinite,
                  );
                },
              ),

              // XP notification
              Center(
                child: AnimatedBuilder(
                  animation:
                      Listenable.merge([_xpScaleAnimation, _xpOpacityAnimation]),
                  builder: (context, child) {
                    return Opacity(
                      opacity: _xpOpacityAnimation.value,
                      child: Transform.scale(
                        scale: _xpScaleAnimation.value,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomIconWidget(
                                iconName: 'stars',
                                color: Colors.white,
                                size: 48,
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                'Task Completed!',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                'Congrats!',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (widget.xpGained > 0) ...[
                                SizedBox(height: 0.5.h),
                                Text(
                                  '+${widget.xpGained} XP',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;
  final List<ConfettiParticle> particles;

  ConfettiPainter(this.progress) : particles = _generateParticles();

  static List<ConfettiParticle> _generateParticles() {
    final random = math.Random();
    return List.generate(20, (index) {
      return ConfettiParticle(
        x: random.nextDouble(),
        y: random.nextDouble() * 0.3,
        color: _getRandomColor(random),
        size: random.nextDouble() * 8 + 4,
        rotation: random.nextDouble() * 2 * math.pi,
        velocityX: (random.nextDouble() - 0.5) * 2,
        velocityY: random.nextDouble() * 3 + 2,
      );
    });
  }

  static Color _getRandomColor(math.Random random) {
    final colors = [
      const Color(0xFFDD2D4A), // Dark red/maroon
      const Color(0xFF880D1E), // Darker red
      const Color(0xFFF49CBB), // Light pink
      const Color(0xFFF26A8D), // Medium pink
      const Color(0xFFCBEEF3), // Light blue/cyan
      Colors.pink,
      Colors.orange,
      Colors.purple,
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      final x = particle.x * size.width + particle.velocityX * progress * 100;
      final y = particle.y * size.height +
          particle.velocityY * progress * size.height;

      if (y > size.height) continue;

      paint.color = particle.color.withValues(alpha: 1.0 - progress);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + progress * 4);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: particle.size,
        height: particle.size,
      );
      canvas.drawRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class ConfettiParticle {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double rotation;
  final double velocityX;
  final double velocityY;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.rotation,
    required this.velocityX,
    required this.velocityY,
  });
}
