import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme/tokens.dart';

/// Satisfying post-submission moment: pop-in check + confetti burst.
class SuccessScreen extends StatelessWidget {
  final String? complaintId;
  final bool queued;

  const SuccessScreen({super.key, this.complaintId, this.queued = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const _ConfettiLayer(),
            Padding(
              padding: const EdgeInsets.all(Space.xl),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: BrandColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 64),
                  )
                      .animate()
                      .scale(
                          duration: 500.ms,
                          curve: Curves.elasticOut,
                          begin: const Offset(0.3, 0.3))
                      .then()
                      .shimmer(duration: 700.ms),
                  const SizedBox(height: Space.xl),
                  Text(queued ? 'Saved — will send soon' : 'Complaint submitted!',
                          style: theme.textTheme.headlineMedium,
                          textAlign: TextAlign.center)
                      .animate()
                      .fadeIn(delay: 200.ms),
                  const SizedBox(height: Space.md),
                  Text(
                    queued
                        ? 'You\'re offline right now. Your complaint is safely queued '
                            'and will submit itself the moment you\'re back online.'
                        : 'Our AI is routing it to the right department. '
                            'Track live progress in My Complaints — you\'ll be '
                            'notified at every step.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.textTheme.bodySmall?.color),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 350.ms),
                  const Spacer(),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    child: const Text('Done'),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lightweight confetti burst without an external package.
class _ConfettiLayer extends StatelessWidget {
  const _ConfettiLayer();

  static const _colors = [
    BrandColors.primary,
    BrandColors.accent,
    BrandColors.success,
    BrandColors.info,
    BrandColors.primaryLight,
  ];

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(7);
    return IgnorePointer(
      child: Stack(
        children: List.generate(26, (i) {
          final left = rng.nextDouble();
          final size = 6.0 + rng.nextDouble() * 8;
          final delay = (rng.nextDouble() * 400).ms;
          final duration = (1200 + rng.nextInt(900)).ms;
          final color = _colors[i % _colors.length];
          return Positioned(
            top: -20,
            left: MediaQuery.of(context).size.width * left,
            child: Container(
              width: size,
              height: size * (rng.nextBool() ? 1 : 2.2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            )
                .animate(delay: delay)
                .moveY(
                    begin: 0,
                    end: MediaQuery.of(context).size.height * 0.85,
                    duration: duration,
                    curve: Curves.easeIn)
                .rotate(begin: 0, end: rng.nextDouble() * 4 - 2, duration: duration)
                .fadeOut(delay: duration * 0.6, duration: duration * 0.4),
          );
        }),
      ),
    );
  }
}
