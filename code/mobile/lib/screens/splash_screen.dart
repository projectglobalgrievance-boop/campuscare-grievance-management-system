import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'admin/admin_shell.dart';
import 'auth/login_screen.dart';
import '../widgets/brand_logo.dart';
import 'onboarding_screen.dart';
import 'student/student_shell.dart';

/// Animated splash that routes on auth state:
/// signed out -> onboarding (first launch) or login; student/admin -> shells.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _routed = false;

  Future<void> _route(AppState app) async {
    if (_routed || app.phase == AuthPhase.loading) return;
    // Let the logo animation breathe.
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    _routed = true;

    Widget next;
    if (app.phase == AuthPhase.signedOut) {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool('onboarding_done') ?? false;
      next = seen ? const LoginScreen() : const OnboardingScreen();
    } else if (app.profile?.isAdmin ?? false) {
      next = const AdminShell();
    } else {
      next = const StudentShell();
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: Motion.slow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route(app));
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [BrandColors.primaryDark, BrandColors.primary],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GatEmblemChip(size: 104)
                  .animate()
                  .scale(
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                      begin: const Offset(0.6, 0.6))
                  .then()
                  .shimmer(duration: 900.ms),
              const SizedBox(height: Space.lg),
              Text(AppConfig.appName,
                      style: theme.textTheme.displaySmall
                          ?.copyWith(color: Colors.white))
                  .animate()
                  .fadeIn(delay: 250.ms, duration: Motion.slow)
                  .slideY(begin: 0.3, delay: 250.ms, duration: Motion.slow),
              const SizedBox(height: Space.xs),
              Text('See it. Snap it. Sorted.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.white70))
                  .animate()
                  .fadeIn(delay: 450.ms, duration: Motion.slow),
            ],
          ),
        ),
      ),
    );
  }
}
