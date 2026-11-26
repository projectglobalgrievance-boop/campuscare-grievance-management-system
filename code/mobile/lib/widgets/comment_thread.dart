import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/complaint.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';

/// Student <-> admin conversation under a complaint. The student is shown as
/// "You"/the alias — never a real name — and comments are immutable.
class CommentThread extends StatefulWidget {
  final String complaintId;

  /// 'student' or 'admin' — which side the current viewer posts as.
  final String viewerRole;
  const CommentThread(
      {super.key, required this.complaintId, required this.viewerRole});

  @override
  State<CommentThread> createState() => _CommentThreadState();
}

class _CommentThreadState extends State<CommentThread> {
  final _text = TextEditingController();
  bool _sending = false;

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await context.read<AppState>().complaints.addComment(widget.complaintId,
          byRole: widget.viewerRole, text: text);
      _text.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.read<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COMMENTS', style: theme.textTheme.labelMedium),
        const SizedBox(height: Space.sm),
        StreamBuilder<List<ComplaintComment>>(
          stream: app.complaints.comments(widget.complaintId),
          builder: (context, snap) {
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: Text('No comments yet.',
                    style: theme.textTheme.bodySmall),
              );
            }
            return Column(
              children: [
                for (final m in items)
                  Align(
                    alignment: m.byRole == widget.viewerRole
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: Space.sm),
                      padding: const EdgeInsets.symmetric(
                          horizontal: Space.md, vertical: Space.sm),
                      constraints: const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(
                        color: m.byRole == widget.viewerRole
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(Corners.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              m.byRole == 'admin' ? 'Admin' : 'Reporter',
                              style: theme.textTheme.labelSmall),
                          Text(m.text, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _text,
                decoration:
                    const InputDecoration(hintText: 'Write a comment…'),
                minLines: 1,
                maxLines: 3,
                maxLength: 1000,
                buildCounter: (_, {required currentLength,
                        required isFocused, maxLength}) =>
                    null,
              ),
            ),
            const SizedBox(width: Space.sm),
            IconButton.filled(
              onPressed: _sending ? null : _send,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

/// A complaint's photo proof, for both detail screens: the photos, full
/// screen on tap, and a line saying where and when they were taken. Reads
/// Storage URLs on older complaints and Firestore-held photos on new ones.
class ComplaintPhotos extends StatelessWidget {
  final Complaint complaint;
  const ComplaintPhotos({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    final c = complaint;
    if (c.allPhotos.isNotEmpty) {
      return _withCaption(context,
          [for (final u in c.allPhotos) NetworkImage(u)]);
    }
    if (c.photoCount == 0) return const SizedBox.shrink();
    return StreamBuilder<List<Uint8List>>(
      stream: context.read<AppState>().complaints.photos(c.id),
      builder: (context, snap) {
        final photos = snap.data;
        if (photos == null) {
          return Container(
            height: 230,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(Corners.md),
            ),
            alignment: Alignment.center,
            child: snap.hasError
                ? const Icon(Icons.broken_image_rounded)
                : const CircularProgressIndicator(strokeWidth: 2.5),
          );
        }
        return _withCaption(
            context, [for (final b in photos) MemoryImage(b)]);
      },
    );
  }

  Widget _withCaption(BuildContext context, List<ImageProvider> images) {
    if (images.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final when = DateFormat('d MMM, h:mm a').format(complaint.capturedAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PhotoGallery(images: images, heroPrefix: 'photo-${complaint.id}'),
        const SizedBox(height: Space.xs + 2),
        Row(
          children: [
            const Icon(Icons.verified_rounded,
                size: 16, color: BrandColors.success),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${images.length == 1 ? 'Photo proof' : '${images.length} photo proofs'}'
                ' · taken in the app at ${complaint.location.zoneName}, $when',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Horizontal photo gallery; tap a photo to see it full screen.
class PhotoGallery extends StatelessWidget {
  final List<ImageProvider> images;
  final String heroPrefix;
  const PhotoGallery(
      {super.key, required this.images, required this.heroPrefix});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    if (images.length == 1) {
      return _photo(context, theme, 0, height: 230);
    }
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: Space.sm),
        itemBuilder: (_, i) => AspectRatio(
          aspectRatio: 4 / 3,
          child: _photo(context, theme, i, height: 200),
        ),
      ),
    );
  }

  Widget _photo(BuildContext context, ThemeData theme, int i,
          {required double height}) =>
      GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => _FullPhoto(
                image: images[i], hero: '$heroPrefix-$i'))),
        child: Hero(
          tag: '$heroPrefix-$i',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Corners.md),
            child: Image(
                image: images[i],
                height: height,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                      height: height,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_rounded),
                    )),
          ),
        ),
      );
}

class _FullPhoto extends StatelessWidget {
  final ImageProvider image;
  final String hero;
  const _FullPhoto({required this.image, required this.hero});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Photo proof'),
        ),
        body: Center(
          child: InteractiveViewer(
            maxScale: 5,
            child: Hero(tag: hero, child: Image(image: image)),
          ),
        ),
      );
}
