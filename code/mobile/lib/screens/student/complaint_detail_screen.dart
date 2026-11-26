import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/complaint.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/badges.dart';
import '../../widgets/comment_thread.dart';
import '../../widgets/feedback_states.dart';
import '../../widgets/status_timeline.dart';

/// Student-side complaint detail: photo hero, AI analysis, live timeline,
/// one-time feedback after resolution.
class ComplaintDetailScreen extends StatelessWidget {
  final String complaintId;
  const ComplaintDetailScreen({super.key, required this.complaintId});

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
            return const ErrorState(
                message: 'This complaint could not be found.');
          }
          return _Body(complaint: c);
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Complaint complaint;
  const _Body({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = complaint;

    return ListView(
      padding: const EdgeInsets.all(Space.md),
      children: [
        ComplaintPhotos(complaint: c),
        const SizedBox(height: Space.md),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusBadge(c.status),
            if (c.ai != null) PriorityChip(c.ai!.priority),
            ZoneChip(c.location.zoneName),
          ],
        ),
        const SizedBox(height: Space.md),
        if (c.description.isNotEmpty) ...[
          Text(c.description, style: theme.textTheme.bodyLarge),
          const SizedBox(height: Space.md),
        ],
        if (c.ai != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: Space.sm),
                      Text('AI ANALYSIS', style: theme.textTheme.labelMedium),
                    ],
                  ),
                  const SizedBox(height: Space.sm + 4),
                  _kv(theme, 'Category', c.ai!.category),
                  _kv(theme, 'Department', c.deptName),
                  _kv(theme, 'Priority', c.ai!.priority),
                ],
              ),
            ),
          ).animate().fadeIn(duration: Motion.normal)
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Text('AI is analyzing this complaint…',
                        style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: Space.lg),
        // Still editable while nobody has picked it up.
        if (c.status == 'submitted') ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editDescription(context, c),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _cancel(context, c),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Cancel complaint'),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
        ],
        Text('PROGRESS', style: theme.textTheme.labelMedium),
        const SizedBox(height: Space.sm),
        StatusTimeline(history: c.statusHistory),
        const SizedBox(height: Space.lg),
        if (c.status == 'resolved' && c.feedback == null)
          _FeedbackCard(complaintId: c.id),
        if (c.feedback != null) _FeedbackDone(feedback: c.feedback!),
        // Rated poorly and still resolved? Put it back in the queue.
        if (c.status == 'resolved' &&
            c.feedback != null &&
            c.feedback!.rating <= 2) ...[
          const SizedBox(height: Space.sm),
          FilledButton.tonalIcon(
            onPressed: () => _reopen(context, c),
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: const Text('Not fixed? Reopen this complaint'),
          ),
        ],
        const SizedBox(height: Space.lg),
        CommentThread(complaintId: c.id, viewerRole: 'student'),
        const SizedBox(height: Space.xl),
      ],
    );
  }

  Future<void> _editDescription(BuildContext context, Complaint c) async {
    final controller = TextEditingController(text: c.description);
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit description',
            style: Theme.of(ctx).textTheme.titleMedium),
        content: TextField(
            controller: controller, maxLines: 4, maxLength: 500,
            autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (text == null || !context.mounted) return;
    await context.read<AppState>().complaints.editDescription(c.id, text);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Description updated.')));
    }
  }

  Future<void> _cancel(BuildContext context, Complaint c) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel this complaint?',
            style: Theme.of(ctx).textTheme.titleMedium),
        content: const Text(
            'It will be closed and admins will stop working on it.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep it')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Cancel complaint')),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    await context.read<AppState>().complaints.cancelComplaint(c.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint cancelled.')));
    }
  }

  Future<void> _reopen(BuildContext context, Complaint c) async {
    await context.read<AppState>().complaints.reopen(c.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Reopened — it\'s back in the admin queue.')));
    }
  }

  Widget _kv(ThemeData theme, String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: Space.xs + 2),
        child: Row(
          children: [
            SizedBox(
                width: 90,
                child: Text(k, style: theme.textTheme.bodySmall)),
            Expanded(child: Text(v, style: theme.textTheme.titleSmall)),
          ],
        ),
      );
}

class _FeedbackCard extends StatefulWidget {
  final String complaintId;
  const _FeedbackCard({required this.complaintId});

  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> {
  int _rating = 0;
  final _comment = TextEditingController();
  bool _busy = false;

  Future<void> _send() async {
    if (_rating == 0) return;
    setState(() => _busy = true);
    await context.read<AppState>().complaints.submitFeedback(
        widget.complaintId,
        _rating,
        _comment.text.trim().isEmpty ? null : _comment.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How was the fix?', style: theme.textTheme.titleMedium),
            const SizedBox(height: Space.sm),
            Row(
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: filled
                              ? BrandColors.warning
                              : theme.colorScheme.outline,
                          size: 32)
                      .animate(target: filled ? 1 : 0)
                      .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.2, 1.2),
                          duration: Motion.fast,
                          curve: Curves.easeOutBack),
                );
              }),
            ),
            TextField(
              controller: _comment,
              decoration:
                  const InputDecoration(hintText: 'Any comments? (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: Space.md),
            FilledButton(
              onPressed: _rating == 0 || _busy ? null : _send,
              child: const Text('Submit feedback'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: Motion.normal).slideY(begin: 0.1);
  }
}

class _FeedbackDone extends StatelessWidget {
  final ComplaintFeedback feedback;
  const _FeedbackDone({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Row(
          children: [
            const Icon(Icons.reviews_rounded, color: BrandColors.success),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                        5,
                        (i) => Icon(
                            i < feedback.rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 18,
                            color: BrandColors.warning)),
                  ),
                  if (feedback.comment != null)
                    Text(feedback.comment!,
                        style: theme.textTheme.bodySmall),
                  Text('Thanks for your feedback!',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
