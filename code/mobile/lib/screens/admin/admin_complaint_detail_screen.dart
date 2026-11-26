import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/complaint.dart';
import '../../services/geofence.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/badges.dart';
import '../../widgets/comment_thread.dart';
import '../../widgets/feedback_states.dart';
import '../../widgets/status_timeline.dart';

/// Admin detail: tagline-first, alias-only sender, map context, AI analysis,
/// lifecycle actions (assign / progress / resolve / reject-with-note).
class AdminComplaintDetailScreen extends StatelessWidget {
  final String complaintId;
  const AdminComplaintDetailScreen({super.key, required this.complaintId});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint')),
      body: StreamBuilder<Complaint?>(
        stream: app.complaints.watch(complaintId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SkeletonList(items: 3, height: 140);
          }
          final c = snap.data;
          if (c == null) {
            return const ErrorState(message: 'Complaint not found.');
          }
          return _Body(c: c);
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Complaint c;
  const _Body({required this.c});

  Future<void> _act(BuildContext context, String newStatus) async {
    final app = context.read<AppState>();
    String? note;
    if (newStatus == 'rejected' || newStatus == 'resolved') {
      note = await showDialog<String>(
        context: context,
        builder: (ctx) => _NoteDialog(
          title: newStatus == 'rejected'
              ? 'Reason for rejection (required)'
              : 'Resolution note (optional)',
          required: newStatus == 'rejected',
        ),
      );
      if (newStatus == 'rejected' && (note == null || note.trim().isEmpty)) {
        return; // rejection always requires a note
      }
    }
    await app.complaints
        .updateStatus(complaint: c, newStatus: newStatus, note: note);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status updated to ${statusLabel(newStatus)}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(Space.md),
      children: [
        if (c.ai != null && c.ai!.tagline.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [BrandColors.primary, BrandColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(Corners.md),
            ),
            child: Row(
              children: [
                const Icon(Icons.campaign_rounded, color: Colors.white),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Text(c.ai!.tagline,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.white)),
                ),
              ],
            ),
          ).animate().fadeIn(duration: Motion.normal).slideY(begin: -0.1),
        const SizedBox(height: Space.md),
        ComplaintPhotos(complaint: c),
        const SizedBox(height: Space.md),
        Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(c.aliasName.characters.first,
                  style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer)),
            ),
            const SizedBox(width: Space.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.aliasName, style: theme.textTheme.titleSmall),
                  Text('Anonymous reporter · identity protected',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            StatusBadge(c.status),
          ],
        ),
        const SizedBox(height: Space.md),
        if (c.description.isNotEmpty) ...[
          Text(c.description, style: theme.textTheme.bodyLarge),
          const SizedBox(height: Space.md),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DETAILS', style: theme.textTheme.labelMedium),
                const SizedBox(height: Space.sm),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    if (c.ai != null) ...[
                      Chip(
                          avatar: Icon(CategoryIcon.iconFor(c.ai!.category),
                              size: 16),
                          label: Text(c.ai!.category)),
                      PriorityChip(c.ai!.priority),
                    ],
                    Chip(
                        avatar: const Icon(Icons.place_rounded, size: 16),
                        label: Text(c.location.zoneName)),
                    Chip(
                        avatar: const Icon(Icons.apartment_rounded, size: 16),
                        label: Text(c.deptName)),
                    // The student chose the department; if the text reads
                    // like another one, say so — the admin decides.
                    if (c.ai?.predictedCategory != null &&
                        c.ai!.predictedCategory != c.ai!.category)
                      Chip(
                          avatar: const Icon(Icons.auto_awesome_rounded,
                              size: 16),
                          label: Text(
                              'AI reads it as ${c.ai!.predictedCategory}')),
                    if (c.escalated)
                      const Chip(
                          avatar: Icon(Icons.local_fire_department_rounded,
                              size: 16, color: BrandColors.warning),
                          label: Text('Escalated — SLA breached')),
                    if (c.ai?.flagged ?? false)
                      const Chip(
                          avatar: Icon(Icons.report_gmailerrorred_rounded,
                              size: 16),
                          label: Text('Flagged wording')),
                    if (c.ai?.duplicateOf != null)
                      ActionChip(
                        avatar: const Icon(Icons.copy_all_rounded, size: 16),
                        label: const Text('Possible duplicate — view'),
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => AdminComplaintDetailScreen(
                                    complaintId: c.ai!.duplicateOf!))),
                      ),
                  ],
                ),
                const SizedBox(height: Space.sm),
                _MapContext(
                    lat: c.location.lat,
                    lng: c.location.lng,
                    accuracy: c.location.accuracy),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.md),
        if (c.isOpen) ...[
          Text('ACTIONS', style: theme.textTheme.labelMedium),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              if (c.status == 'submitted')
                FilledButton.tonalIcon(
                  onPressed: () => _act(context, 'assigned'),
                  icon: const Icon(Icons.assignment_ind_rounded, size: 18),
                  label: Text('Assign to ${c.deptName}'),
                ),
              if (c.status == 'assigned')
                FilledButton.tonalIcon(
                  onPressed: () => _act(context, 'in_progress'),
                  icon: const Icon(Icons.engineering_rounded, size: 18),
                  label: const Text('Mark in progress'),
                ),
              FilledButton.icon(
                onPressed: () => _act(context, 'resolved'),
                icon: const Icon(Icons.task_alt_rounded, size: 18),
                label: const Text('Resolve'),
              ),
              OutlinedButton.icon(
                onPressed: () => _act(context, 'rejected'),
                icon: const Icon(Icons.block_rounded, size: 18),
                label: const Text('Reject'),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
        ],
        Text('HISTORY', style: theme.textTheme.labelMedium),
        const SizedBox(height: Space.sm),
        StatusTimeline(history: c.statusHistory),
        if (c.feedback != null) ...[
          const SizedBox(height: Space.md),
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.reviews_rounded, color: BrandColors.warning),
              title: Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                        i < c.feedback!.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 18,
                        color: BrandColors.warning)),
              ),
              subtitle: Text(c.feedback!.comment ?? 'No comment'),
            ),
          ),
        ],
        const SizedBox(height: Space.lg),
        CommentThread(complaintId: c.id, viewerRole: 'admin'),
        const SizedBox(height: Space.xl),
      ],
    );
  }
}

/// Schematic campus map: draws the boundary + a pin, no network tiles needed.
class _MapContext extends StatelessWidget {
  final double lat;
  final double lng;
  final double accuracy;
  const _MapContext(
      {required this.lat, required this.lng, required this.accuracy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(Corners.sm),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _CampusPainter(
                lat: lat,
                lng: lng,
                boundaryColor: theme.colorScheme.primary,
                zoneColor:
                    theme.colorScheme.primary.withValues(alpha: 0.08),
                pinColor: BrandColors.accent,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    isInsideCampus(lat, lng)
                        ? 'Captured inside campus'
                        : 'Captured OFF campus (demo)',
                    style: theme.textTheme.labelMedium),
                const SizedBox(height: 2),
                Text('±${accuracy.toStringAsFixed(0)} m GPS',
                    style: theme.textTheme.bodySmall),
                Text(
                    '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CampusPainter extends CustomPainter {
  final double lat;
  final double lng;
  final Color boundaryColor;
  final Color zoneColor;
  final Color pinColor;

  _CampusPainter({
    required this.lat,
    required this.lng,
    required this.boundaryColor,
    required this.zoneColor,
    required this.pinColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Normalize campus bounds into the canvas — derived from the real
    // boundary polygon so a re-traced campus never breaks the map.
    final all = campusBoundaryForPainting();
    var minLat = all.first.$1, maxLat = all.first.$1;
    var minLng = all.first.$2, maxLng = all.first.$2;
    for (final (la, ln) in all) {
      if (la < minLat) minLat = la;
      if (la > maxLat) maxLat = la;
      if (ln < minLng) minLng = ln;
      if (ln > maxLng) maxLng = ln;
    }
    final padLat = (maxLat - minLat) * 0.08;
    final padLng = (maxLng - minLng) * 0.08;
    minLat -= padLat; maxLat += padLat;
    minLng -= padLng; maxLng += padLng;
    Offset project(double la, double ln) => Offset(
          (ln - minLng) / (maxLng - minLng) * size.width,
          (1 - (la - minLat) / (maxLat - minLat)) * size.height,
        );

    final boundary = Path();
    final pts = campusBoundaryForPainting();
    for (var i = 0; i < pts.length; i++) {
      final o = project(pts[i].$1, pts[i].$2);
      i == 0 ? boundary.moveTo(o.dx, o.dy) : boundary.lineTo(o.dx, o.dy);
    }
    boundary.close();
    canvas.drawPath(boundary, Paint()..color = zoneColor);
    canvas.drawPath(
        boundary,
        Paint()
          ..color = boundaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    final pin = project(lat, lng);
    canvas.drawCircle(
        pin, 10, Paint()..color = pinColor.withValues(alpha: 0.25));
    canvas.drawCircle(pin, 4.5, Paint()..color = pinColor);
  }

  @override
  bool shouldRepaint(covariant _CampusPainter old) =>
      old.lat != lat || old.lng != lng;
}

class _NoteDialog extends StatefulWidget {
  final String title;
  final bool required;
  const _NoteDialog({required this.title, required this.required});

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title,
          style: Theme.of(context).textTheme.titleMedium),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(hintText: 'Write a note…'),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: widget.required && _controller.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
