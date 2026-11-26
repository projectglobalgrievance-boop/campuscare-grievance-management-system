import 'package:flutter/material.dart';

import '../models/complaint.dart';
import '../theme/tokens.dart';

class PriorityChip extends StatelessWidget {
  final String priority;
  final bool compact;
  const PriorityChip(this.priority, {super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = PriorityColors.of(priority);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? Space.sm : Space.sm + 2, vertical: Space.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Corners.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 13, color: color),
          const SizedBox(width: 4),
          Text(priority,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = StatusColors.of(status);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Space.sm + 2, vertical: Space.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Corners.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(statusLabel(status),
          style:
              Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
    );
  }
}

class ZoneChip extends StatelessWidget {
  final String zone;
  const ZoneChip(this.zone, {super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.place_rounded, size: 14, color: scheme.primary),
        const SizedBox(width: 2),
        Text(zone,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: scheme.primary)),
      ],
    );
  }
}

class CategoryIcon extends StatelessWidget {
  final String category;
  final double size;
  const CategoryIcon(this.category, {super.key, this.size = 20});

  static IconData iconFor(String category) => switch (category) {
        'Cleanliness' => Icons.cleaning_services_rounded,
        'Electrical' => Icons.electric_bolt_rounded,
        'Plumbing' => Icons.water_drop_rounded,
        'Furniture' => Icons.chair_rounded,
        'Academics' => Icons.school_rounded,
        'Hostel' => Icons.night_shelter_rounded,
        _ => Icons.category_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size * 2.1,
      height: size * 2.1,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(Corners.sm),
      ),
      child: Icon(iconFor(category),
          size: size, color: scheme.onPrimaryContainer),
    );
  }
}
