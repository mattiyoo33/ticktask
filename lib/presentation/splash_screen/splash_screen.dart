import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _animationController.forward();

    // Check auth state and navigate accordingly
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for animation to complete
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // TEMPORARY: Always show onboarding for testing
    // TODO: Remove this and uncomment the check below when done testing
    Navigator.pushReplacementNamed(context, AppRoutes.onboardingWelcome);
    return;

    // Check if onboarding has been completed
    // final onboardingService = OnboardingService();
    // final hasCompletedOnboarding = await onboardingService.hasCompletedOnboarding();

    // if (!hasCompletedOnboarding) {
    //   // Show onboarding flow for first-time users
    //   Navigator.pushReplacementNamed(context, AppRoutes.onboardingWelcome);
    //   return;
    // }

    // // Check if user is authenticated
    // final isAuthenticated = ref.read(isAuthenticatedProvider);

    // if (isAuthenticated) {
    //   // User is logged in, go to dashboard
    //   Navigator.pushReplacementNamed(context, AppRoutes.homeDashboard);
    // } else {
    //   // User is not logged in, go to login
    //   Navigator.pushReplacementNamed(context, AppRoutes.login);
    // }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Design spec: red gradient (red-500 to red-600), Tasker mascot, white text
    const Color splashRed500 = Color(0xFFEF4444);
    const Color splashRed600 = Color(0xFFDC2626);
    const Color taglineRed100 = Color(0xFFFEE2E2);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [splashRed500, splashRed600],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Tasker mascot (ant) - white rounded container, 28px radius per design spec
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Image.asset(
                                'assets/images/tasker_mascot.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        // App Name - 48px bold white per design spec
                        Text(
                          'TickTask',
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontSize: 48,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        // Tagline - 18px red-100 per design spec
                        Text(
                          'Your productivity companion',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                            color: taglineRed100,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        // Loading indicator - white per design spec
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.9),
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

