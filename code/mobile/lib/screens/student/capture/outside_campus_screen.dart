import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/app_config.dart';
import '../../../theme/tokens.dart';

/// The geofence rejection — deliberately beautiful. The photo is discarded;
/// nothing was uploaded.
class OutsideCampusScreen extends StatelessWidget {
  const OutsideCampusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            children: [
              const Spacer(),
              // Friendly map-pin illustration built from shapes.
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                            begin: const Offset(0.92, 0.92),
                            end: const Offset(1, 1),
                            duration: 1400.ms),
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Icon(Icons.fmd_bad_rounded,
                            size: 84, color: theme.colorScheme.primary)
                        .animate()
                        .scale(
                            duration: Motion.slow,
                            curve: Curves.easeOutBack,
                            begin: const Offset(0.5, 0.5)),
                  ],
                ),
              ),
              const SizedBox(height: Space.xl),
              Text('You\'re outside the campus',
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center)
                  .animate()
                  .fadeIn(delay: 150.ms, duration: Motion.normal),
              const SizedBox(height: Space.md),
              Text(
                'Complaints can only be submitted from inside '
                '${AppConfig.campusName}. Your photo was not uploaded.\n\n'
                'Head back to campus and try again — the problem will still '
                'be there, sadly. 🙂',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.textTheme.bodySmall?.color),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms, duration: Motion.normal),
              const Spacer(),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Got it'),
              ).animate().fadeIn(delay: 400.ms, duration: Motion.normal),
            ],
          ),
        ),
      ),
    );
  }
}
