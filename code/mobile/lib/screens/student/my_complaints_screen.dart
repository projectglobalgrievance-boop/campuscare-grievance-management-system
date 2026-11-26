import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/complaint.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/complaint_card.dart';
import '../../widgets/feedback_states.dart';
import 'capture/camera_screen.dart';
import 'complaint_detail_screen.dart';

enum _Filter { all, active, resolved }

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final uid = app.auth.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Space.md, Space.md, Space.md, Space.sm),
            child: Text('My Complaints',
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.md),
            child: SegmentedButton<_Filter>(
              segments: const [
                ButtonSegment(value: _Filter.all, label: Text('All')),
                ButtonSegment(value: _Filter.active, label: Text('Active')),
                ButtonSegment(value: _Filter.resolved, label: Text('Resolved')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
              showSelectedIcon: false,
            ),
          ),
          const SizedBox(height: Space.sm),
          Expanded(
            child: StreamBuilder<List<Complaint>>(
              stream: app.complaints.myComplaints(uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SkeletonList();
                }
                if (snap.hasError) {
                  return ErrorState(
                      message:
                          'Couldn\'t load your complaints. Pull to retry.',
                      onRetry: () => setState(() {}));
                }
                var items = snap.data ?? [];
                items = switch (_filter) {
                  _Filter.all => items,
                  _Filter.active =>
                    items.where((c) => c.isOpen).toList(),
                  _Filter.resolved => items
                      .where((c) =>
                          c.status == 'resolved' || c.status == 'rejected')
                      .toList(),
                };
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: _filter == _Filter.all
                        ? 'Nothing here yet'
                        : 'No ${_filter.name} complaints',
                    message:
                        'When you report a problem it shows up here with live status tracking.',
                    action: _filter == _Filter.all
                        ? FilledButton.tonalIcon(
                            onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const CameraScreen())),
                            icon: const Icon(Icons.photo_camera_rounded),
                            label: const Text('Report a problem'),
                          )
                        : null,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(Space.md),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: Space.md),
                    itemBuilder: (_, i) => ComplaintCard(
                      complaint: items[i],
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => ComplaintDetailScreen(
                                  complaintId: items[i].id))),
                    )
                        .animate()
                        .fadeIn(delay: (i * 60).ms, duration: Motion.fast),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
