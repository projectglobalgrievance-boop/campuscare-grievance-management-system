import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/complaint.dart';
import '../theme/tokens.dart';
import 'badges.dart';

/// Complaint list card — used by both student history (shows "You") and the
/// admin queue (shows the funny alias + tagline as the title).
class ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  final bool adminView;
  final VoidCallback onTap;

  const ComplaintCard({
    super.key,
    required this.complaint,
    required this.onTap,
    this.adminView = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = complaint;
    final title = adminView && c.ai != null && c.ai!.tagline.isNotEmpty
        ? c.ai!.tagline
        : (c.description.isEmpty ? 'Photo complaint' : c.description);
    final when = DateFormat('d MMM, h:mm a').format(c.submittedAt);
    final sender = adminView ? c.aliasName : 'You';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'photo-${c.id}',
                child: _Thumb(photoUrl: c.photoUrl, category: c.ai?.category),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: Space.xs + 2),
                    Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ZoneChip(c.location.zoneName),
                        if (c.ai != null) PriorityChip(c.ai!.priority, compact: true),
                        StatusBadge(c.status),
                        if (c.photoCount > 0)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.photo_camera_rounded,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 2),
                            Text('${c.photoCount}',
                                style: theme.textTheme.bodySmall),
                          ]),
                        if (adminView && c.escalated)
                          const Icon(Icons.local_fire_department_rounded,
                              size: 16, color: BrandColors.warning),
                      ],
                    ),
                    const SizedBox(height: Space.xs + 2),
                    Text('$sender · $when',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? photoUrl;
  final String? category;
  const _Thumb({this.photoUrl, this.category});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(Corners.sm),
      ),
      child: Icon(
        category == null
            ? Icons.image_rounded
            : CategoryIcon.iconFor(category!),
        color: scheme.onPrimaryContainer,
      ),
    );
    if (photoUrl == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Corners.sm),
      child: Image.network(
        photoUrl!,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : placeholder,
      ),
    );
  }
}
