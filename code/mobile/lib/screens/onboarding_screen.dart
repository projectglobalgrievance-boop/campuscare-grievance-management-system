import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/tokens.dart';
import 'auth/login_screen.dart';

class _Page {
  final IconData icon;
  final String title;
  final String body;
  const _Page(this.icon, this.title, this.body);
}

const _pages = [
  _Page(Icons.photo_camera_rounded, 'Snap the problem',
      'See an overflowing dustbin or a broken fan? Open the camera and take one photo — right where it happens.'),
  _Page(Icons.psychology_rounded, 'AI does the paperwork',
      'Your complaint is categorized, prioritized and sent to the right department automatically. No forms, no queues.'),
  _Page(Icons.track_changes_rounded, 'Track till it\'s fixed',
      'Follow live status updates from submission to resolution — and rate the fix when it\'s done. Your identity stays private.'),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _index == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: TextButton(
                    onPressed: _finish, child: const Text('Skip')),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: Space.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.primaryContainer,
                                theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.4),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(p.icon,
                              size: 84,
                              color: theme.colorScheme.onPrimaryContainer),
                        )
                            .animate(key: ValueKey('icon$i'))
                            .scale(
                                duration: Motion.slow,
                                curve: Curves.easeOutBack,
                                begin: const Offset(0.7, 0.7)),
                        const SizedBox(height: Space.xxl),
                        Text(p.title,
                                style: theme.textTheme.headlineMedium,
                                textAlign: TextAlign.center)
                            .animate(key: ValueKey('title$i'))
                            .fadeIn(duration: Motion.normal)
                            .slideY(begin: 0.2),
                        const SizedBox(height: Space.md),
                        Text(p.body,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.textTheme.bodySmall?.color),
                                textAlign: TextAlign.center)
                            .animate(key: ValueKey('body$i'))
                            .fadeIn(delay: 100.ms, duration: Motion.normal),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: Motion.fast,
                        margin:
                            const EdgeInsets.symmetric(horizontal: Space.xs),
                        width: i == _index ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius:
                              BorderRadius.circular(Corners.pill),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.lg),
                  FilledButton(
                    onPressed: isLast
                        ? _finish
                        : () => _controller.nextPage(
                            duration: Motion.normal, curve: Motion.curve),
                    child: Text(isLast ? 'Get started' : 'Next'),
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
