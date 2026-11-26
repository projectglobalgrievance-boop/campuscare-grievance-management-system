import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../models/complaint.dart';
import '../theme/tokens.dart';

/// Vertical animated status timeline for the complaint detail screen.
class StatusTimeline extends StatelessWidget {
  final List<StatusEntry> history;
  const StatusTimeline({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = [...history]..sort((a, b) => a.at.compareTo(b.at));
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _TimelineRow(
            entry: entries[i],
            isFirst: i == 0,
            isLast: i == entries.length - 1,
            theme: theme,
          )
              .animate()
              .fadeIn(delay: (i * 90).ms, duration: Motion.normal)
              .slideX(begin: 0.08, delay: (i * 90).ms, duration: Motion.normal),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final StatusEntry entry;
  final bool isFirst;
  final bool isLast;
  final ThemeData theme;

  const _TimelineRow({
    required this.entry,
    required this.isFirst,
    required this.isLast,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final color = StatusColors.of(entry.status);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst
                        ? Colors.transparent
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: theme.colorScheme.surface, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                          color: color.withValues(alpha: 0.4), blurRadius: 6)
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.sm + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusLabel(entry.status),
                      style: theme.textTheme.titleSmall?.copyWith(color: color)),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('EEE, d MMM · h:mm a').format(entry.at),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (entry.note != null && entry.note!.isNotEmpty) ...[
                    const SizedBox(height: Space.xs),
                    Container(
                      padding: const EdgeInsets.all(Space.sm),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(Corners.sm),
                        border: Border.all(
                            color: theme.colorScheme.outlineVariant),
                      ),
                      child: Text(entry.note!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
