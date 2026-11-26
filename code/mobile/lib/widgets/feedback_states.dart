import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/tokens.dart';

/// Designed empty state: soft icon medallion + headline + helper line.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 44, color: theme.colorScheme.onPrimaryContainer),
            ).animate().scale(
                duration: Motion.normal,
                curve: Curves.easeOutBack,
                begin: const Offset(0.7, 0.7)),
            const SizedBox(height: Space.lg),
            Text(title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: Space.sm),
            Text(message,
                style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: Space.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Friendly error state with retry.
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Something went wrong',
      message: message,
      action: onRetry == null
          ? null
          : FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
    );
  }
}

/// Shimmer skeleton for loading lists.
class SkeletonList extends StatelessWidget {
  final int items;
  final double height;
  const SkeletonList({super.key, this.items = 4, this.height = 92});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(Space.md),
      itemCount: items,
      separatorBuilder: (_, __) => const SizedBox(height: Space.md),
      itemBuilder: (_, i) => Container(
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(Corners.md),
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1200.ms, delay: (i * 100).ms),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  final bool online;
  final int pendingCount;
  const OfflineBanner(
      {super.key, required this.online, this.pendingCount = 0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (online && pendingCount == 0) return const SizedBox.shrink();
    final text = !online
        ? 'You\'re offline — showing saved data'
        : '$pendingCount complaint${pendingCount == 1 ? '' : 's'} waiting to send…';
    return Material(
      color: !online ? BrandColors.warning : theme.colorScheme.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(!online ? Icons.wifi_off_rounded : Icons.sync_rounded,
                  size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(text,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: -1, duration: Motion.fast);
  }
}

/// Animated count-up number for dashboard tiles.
class CountUp extends StatelessWidget {
  final int value;
  final TextStyle? style;
  const CountUp(this.value, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: Motion.slow,
      curve: Motion.curve,
      builder: (_, v, __) => Text('$v', style: style),
    );
  }
}
